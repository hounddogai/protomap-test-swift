import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive consent form bundle.
    final class AdaptiveConsentFormBundleView {
        var code: String
        var titleText: String
        var maximumText: String
        var retriesText: String
        var limitText: String
        var segmentText: String
        var checksum: String
        var durationMinutesText: String
        var ward: String
        var copay: String
        var visible: String
        var statusLabel: String

        init(code: String, titleText: String, maximumText: String, retriesText: String, limitText: String, segmentText: String, checksum: String, durationMinutesText: String, ward: String, copay: String, visible: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximumText = maximumText
            self.retriesText = retriesText
            self.limitText = limitText
            self.segmentText = segmentText
            self.checksum = checksum
            self.durationMinutesText = durationMinutesText
            self.ward = ward
            self.copay = copay
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveConsentFormBundleView(_ item: AdaptiveConsentFormBundle) -> AdaptiveConsentFormBundleView {
        return AdaptiveConsentFormBundleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            retriesText: String(item.retries),
            limitText: String(item.limit),
            segmentText: item.segment,
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            durationMinutesText: String(item.durationMinutes),
            ward: item.ward,
            copay: String(format: "%.2f", item.copay),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveConsentFormBundleViews(_ items: [AdaptiveConsentFormBundle]) -> [AdaptiveConsentFormBundleView] {
        var views: [AdaptiveConsentFormBundleView] = []
        for item in items {
            views.append(toAdaptiveConsentFormBundleView(item))
        }
        return views
    }

    static func sumAdaptiveConsentFormBundleView(_ view: AdaptiveConsentFormBundleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + Double(parsedLimit)
    }
}
