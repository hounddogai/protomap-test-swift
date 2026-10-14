import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient remittance manifest.
    final class LenientRemittanceManifestView {
        var code: String
        var name: String
        var score: String
        var rateText: String
        var patientRef: String
        var limit: String
        var costText: String
        var revision: String
        var sequence: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, score: String, rateText: String, patientRef: String, limit: String, costText: String, revision: String, sequence: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.rateText = rateText
            self.patientRef = patientRef
            self.limit = limit
            self.costText = costText
            self.revision = revision
            self.sequence = sequence
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRemittanceManifestView(_ item: LenientRemittanceManifest) -> LenientRemittanceManifestView {
        return LenientRemittanceManifestView(
            code: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            rateText: String(format: "%.2f", item.rate),
            patientRef: item.patientRef,
            limit: String(item.limit),
            costText: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            sequence: String(item.sequence),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRemittanceManifestViews(_ items: [LenientRemittanceManifest]) -> [LenientRemittanceManifestView] {
        var views: [LenientRemittanceManifestView] = []
        for item in items {
            views.append(toLenientRemittanceManifestView(item))
        }
        return views
    }

    static func sumLenientRemittanceManifestView(_ view: LenientRemittanceManifestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedScore + parsedRate + Double(parsedLimit)
    }
}
