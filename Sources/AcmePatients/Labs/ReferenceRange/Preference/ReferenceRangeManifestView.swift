import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range manifest.
    final class ReferenceRangeManifestView {
        var code: String
        var name: String
        var limit: String
        var endsAt: String
        var procedureCode: String
        var sequence: String
        var weight: String
        var statusLabel: String

        init(code: String, name: String, limit: String, endsAt: String, procedureCode: String, sequence: String, weight: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeManifestView(_ item: ReferenceRangeManifest) -> ReferenceRangeManifestView {
        return ReferenceRangeManifestView(
            code: item.code,
            name: item.name,
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            procedureCode: item.procedureCode,
            sequence: String(item.sequence),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeManifestViews(_ items: [ReferenceRangeManifest]) -> [ReferenceRangeManifestView] {
        var views: [ReferenceRangeManifestView] = []
        for item in items {
            views.append(toReferenceRangeManifestView(item))
        }
        return views
    }

    static func sumReferenceRangeManifestView(_ view: ReferenceRangeManifestView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedLimit) + Double(parsedEndsAt) + Double(parsedSequence)
    }
}
