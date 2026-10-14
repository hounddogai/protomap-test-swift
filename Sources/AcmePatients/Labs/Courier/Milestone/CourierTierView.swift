import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier tier.
    final class CourierTierView {
        var code: String
        var name: String
        var summary: String
        var allergyText: String
        var sourceText: String
        var visible: String
        var batchSize: String
        var clinicianID: String
        var payer: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, summary: String, allergyText: String, sourceText: String, visible: String, batchSize: String, clinicianID: String, payer: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.summary = summary
            self.allergyText = allergyText
            self.sourceText = sourceText
            self.visible = visible
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.payer = payer
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toCourierTierView(_ item: CourierTier) -> CourierTierView {
        return CourierTierView(
            code: item.code,
            name: item.name,
            summary: item.summary,
            allergyText: item.allergy,
            sourceText: item.source,
            visible: "\(item.visible)",
            batchSize: String(item.batchSize),
            clinicianID: item.clinicianID,
            payer: item.payer,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierTierViews(_ items: [CourierTier]) -> [CourierTierView] {
        var views: [CourierTierView] = []
        for item in items {
            views.append(toCourierTierView(item))
        }
        return views
    }

    static func sumCourierTierView(_ view: CourierTierView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVersion)
    }
}
