import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol profile.
    final class CareProtocolProfileView {
        var code: String
        var title: String
        var minimumText: String
        var sequence: String
        var wardText: String
        var summaryText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, minimumText: String, sequence: String, wardText: String, summaryText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimumText = minimumText
            self.sequence = sequence
            self.wardText = wardText
            self.summaryText = summaryText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolProfileView(_ item: CareProtocolProfile) -> CareProtocolProfileView {
        return CareProtocolProfileView(
            code: item.code,
            title: item.title,
            minimumText: String(format: "%.2f", item.minimum),
            sequence: String(item.sequence),
            wardText: item.ward,
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolProfileViews(_ items: [CareProtocolProfile]) -> [CareProtocolProfileView] {
        var views: [CareProtocolProfileView] = []
        for item in items {
            views.append(toCareProtocolProfileView(item))
        }
        return views
    }

    static func sumCareProtocolProfileView(_ view: CareProtocolProfileView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedMinimum + Double(parsedSequence)
    }
}
