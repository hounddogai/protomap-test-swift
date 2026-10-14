import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped modality window.
    final class CappedModalityWindowView {
        var codeText: String
        var name: String
        var region: String
        var dosageMg: String
        var facility: String
        var statusLabel: String

        init(codeText: String, name: String, region: String, dosageMg: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.region = region
            self.dosageMg = dosageMg
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toCappedModalityWindowView(_ item: CappedModalityWindow) -> CappedModalityWindowView {
        return CappedModalityWindowView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            region: item.region,
            dosageMg: String(format: "%.2f", item.dosageMg),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedModalityWindowViews(_ items: [CappedModalityWindow]) -> [CappedModalityWindowView] {
        var views: [CappedModalityWindowView] = []
        for item in items {
            views.append(toCappedModalityWindowView(item))
        }
        return views
    }

    static func sumCappedModalityWindowView(_ view: CappedModalityWindowView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
