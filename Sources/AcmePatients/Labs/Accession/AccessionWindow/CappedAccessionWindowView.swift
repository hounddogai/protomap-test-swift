import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped accession window.
    final class CappedAccessionWindowView {
        var code: String
        var title: String
        var segment: String
        var externalRef: String
        var dosageMg: String
        var clinicianID: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, title: String, segment: String, externalRef: String, dosageMg: String, clinicianID: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.externalRef = externalRef
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedAccessionWindowView(_ item: CappedAccessionWindow) -> CappedAccessionWindowView {
        return CappedAccessionWindowView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 80),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            externalRef: item.externalRef,
            dosageMg: String(format: "%.2f", item.dosageMg),
            clinicianID: item.clinicianID,
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedAccessionWindowViews(_ items: [CappedAccessionWindow]) -> [CappedAccessionWindowView] {
        var views: [CappedAccessionWindowView] = []
        for item in items {
            views.append(toCappedAccessionWindowView(item))
        }
        return views
    }

    static func sumCappedAccessionWindowView(_ view: CappedAccessionWindowView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDosageMg + Double(parsedEndsAt)
    }
}
