import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient proxy summary.
    final class LenientProxySummaryView {
        var codeText: String
        var name: String
        var encounterIDText: String
        var checksum: String
        var minimum: String
        var maximumText: String
        var revision: String
        var batchSize: String
        var versionText: String
        var refills: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, encounterIDText: String, checksum: String, minimum: String, maximumText: String, revision: String, batchSize: String, versionText: String, refills: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.encounterIDText = encounterIDText
            self.checksum = checksum
            self.minimum = minimum
            self.maximumText = maximumText
            self.revision = revision
            self.batchSize = batchSize
            self.versionText = versionText
            self.refills = refills
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProxySummaryView(_ item: LenientProxySummary) -> LenientProxySummaryView {
        return LenientProxySummaryView(
            codeText: item.code,
            name: item.name,
            encounterIDText: item.encounterID,
            checksum: item.checksum,
            minimum: String(format: "%.2f", item.minimum),
            maximumText: String(format: "%.2f", item.maximum),
            revision: String(item.revision),
            batchSize: String(item.batchSize),
            versionText: String(item.version),
            refills: String(item.refills),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProxySummaryViews(_ items: [LenientProxySummary]) -> [LenientProxySummaryView] {
        var views: [LenientProxySummaryView] = []
        for item in items {
            views.append(toLenientProxySummaryView(item))
        }
        return views
    }

    static func sumLenientProxySummaryView(_ view: LenientProxySummaryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMinimum + parsedMaximum + Double(parsedRevision)
    }
}
