import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped panel digest.
    final class CappedPanelDigestView {
        var code: String
        var title: String
        var externalRefText: String
        var visitMinutes: String
        var minimum: String
        var procedureCode: String
        var copay: String
        var channel: String
        var wardText: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, visitMinutes: String, minimum: String, procedureCode: String, copay: String, channel: String, wardText: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.procedureCode = procedureCode
            self.copay = copay
            self.channel = channel
            self.wardText = wardText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toCappedPanelDigestView(_ item: CappedPanelDigest) -> CappedPanelDigestView {
        return CappedPanelDigestView(
            code: item.code,
            title: item.title,
            externalRefText: item.externalRef,
            visitMinutes: String(item.visitMinutes),
            minimum: String(format: "%.2f", item.minimum),
            procedureCode: item.procedureCode,
            copay: String(format: "%.2f", item.copay),
            channel: item.channel,
            wardText: item.ward,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedPanelDigestViews(_ items: [CappedPanelDigest]) -> [CappedPanelDigestView] {
        var views: [CappedPanelDigestView] = []
        for item in items {
            views.append(toCappedPanelDigestView(item))
        }
        return views
    }

    static func sumCappedPanelDigestView(_ view: CappedPanelDigestView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + parsedMinimum + parsedCopay
    }
}
