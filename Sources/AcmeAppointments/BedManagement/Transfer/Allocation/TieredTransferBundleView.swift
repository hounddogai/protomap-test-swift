import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered transfer bundle.
    final class TieredTransferBundleView {
        var codeText: String
        var label: String
        var sequenceText: String
        var visible: String
        var locale: String
        var specialty: String
        var minimumText: String
        var statusLabel: String

        init(codeText: String, label: String, sequenceText: String, visible: String, locale: String, specialty: String, minimumText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.sequenceText = sequenceText
            self.visible = visible
            self.locale = locale
            self.specialty = specialty
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTransferBundleView(_ item: TieredTransferBundle) -> TieredTransferBundleView {
        return TieredTransferBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            sequenceText: String(item.sequence),
            visible: "\(item.visible)",
            locale: item.locale,
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTransferBundleViews(_ items: [TieredTransferBundle]) -> [TieredTransferBundleView] {
        var views: [TieredTransferBundleView] = []
        for item in items {
            views.append(toTieredTransferBundleView(item))
        }
        return views
    }

    static func sumTieredTransferBundleView(_ view: TieredTransferBundleView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedSequence) + parsedMinimum
    }
}
