#ifndef STARSHIP_JXL_PROVIDER_H
#define STARSHIP_JXL_PROVIDER_H
#include <QFile>
#include <QImage>
#include <QQuickImageProvider>
#include <jxl/decode.h>
#include <memory>

// Qt Quick image provider using the official libjxl decoder. Only bundled resources are read.
class JxlProvider final : public QQuickImageProvider {
public:
    JxlProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override {
        if ((!id.startsWith("photos/") && !id.startsWith("images/")) || id.contains("..")) return {};
        QFile file(":/" + id);
        if (!file.open(QIODevice::ReadOnly)) return {};
        const QByteArray bytes = file.readAll();
        const auto decoder = std::unique_ptr<JxlDecoder, decltype(&JxlDecoderDestroy)>(JxlDecoderCreate(nullptr), JxlDecoderDestroy);
        if (!decoder || JxlDecoderSubscribeEvents(decoder.get(), JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE) != JXL_DEC_SUCCESS) return {};
        if (JxlDecoderSetInput(decoder.get(), reinterpret_cast<const uint8_t *>(bytes.constData()), bytes.size()) != JXL_DEC_SUCCESS) return {};
        JxlDecoderCloseInput(decoder.get());
        const JxlPixelFormat format{4, JXL_TYPE_UINT8, JXL_NATIVE_ENDIAN, 0};
        QImage image;
        for (;;) {
            const auto status = JxlDecoderProcessInput(decoder.get());
            if (status == JXL_DEC_BASIC_INFO) {
                JxlBasicInfo info;
                if (JxlDecoderGetBasicInfo(decoder.get(), &info) != JXL_DEC_SUCCESS ||
                    info.xsize == 0 || info.ysize == 0 || static_cast<uint64_t>(info.xsize) * info.ysize > 40000000) return {};
                image = QImage(info.xsize, info.ysize, QImage::Format_RGBA8888);
                if (image.isNull()) return {};
            } else if (status == JXL_DEC_NEED_IMAGE_OUT_BUFFER) {
                size_t bytesNeeded = 0;
                if (image.isNull() || JxlDecoderImageOutBufferSize(decoder.get(), &format, &bytesNeeded) != JXL_DEC_SUCCESS ||
                    bytesNeeded != static_cast<size_t>(image.sizeInBytes()) ||
                    JxlDecoderSetImageOutBuffer(decoder.get(), &format, image.bits(), bytesNeeded) != JXL_DEC_SUCCESS) return {};
            } else if (status == JXL_DEC_FULL_IMAGE) {
                if (size) *size = image.size();
                if (requestedSize.width() > 0 && requestedSize.width() < image.width()) {
                    return image.scaledToWidth(requestedSize.width(), Qt::SmoothTransformation);
                }
                return image;
            } else if (status == JXL_DEC_ERROR || status == JXL_DEC_NEED_MORE_INPUT || status == JXL_DEC_SUCCESS) {
                return {};
            }
        }
    }
};
#endif
