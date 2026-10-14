import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient language checkpoint.
    final class LenientLanguageCheckpointView {
        var code: String
        var titleText: String
        var checksum: String
        var description: String
        var refills: String
        var clinicianID: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, checksum: String, description: String, refills: String, clinicianID: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.checksum = checksum
            self.description = description
            self.refills = refills
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toLenientLanguageCheckpointView(_ item: LenientLanguageCheckpoint) -> LenientLanguageCheckpointView {
        return LenientLanguageCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            checksum: item.checksum,
            description: Kit.Text.truncate(item.description, limit: 40),
            refills: String(item.refills),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientLanguageCheckpointViews(_ items: [LenientLanguageCheckpoint]) -> [LenientLanguageCheckpointView] {
        var views: [LenientLanguageCheckpointView] = []
        for item in items {
            views.append(toLenientLanguageCheckpointView(item))
        }
        return views
    }

    static func sumLenientLanguageCheckpointView(_ view: LenientLanguageCheckpointView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedRefills) + parsedRatio
    }
}
