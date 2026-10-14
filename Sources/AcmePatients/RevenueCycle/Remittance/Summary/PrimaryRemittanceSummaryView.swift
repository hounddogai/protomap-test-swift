import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary remittance summary.
    final class PrimaryRemittanceSummaryView {
        var code: String
        var label: String
        var diagnosisCode: String
        var unitText: String
        var refills: String
        var batchSizeText: String
        var graceDays: String
        var version: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, unitText: String, refills: String, batchSizeText: String, graceDays: String, version: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.unitText = unitText
            self.refills = refills
            self.batchSizeText = batchSizeText
            self.graceDays = graceDays
            self.version = version
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRemittanceSummaryView(_ item: PrimaryRemittanceSummary) -> PrimaryRemittanceSummaryView {
        return PrimaryRemittanceSummaryView(
            code: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            unitText: item.unit,
            refills: String(item.refills),
            batchSizeText: String(item.batchSize),
            graceDays: String(item.graceDays),
            version: String(item.version),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRemittanceSummaryViews(_ items: [PrimaryRemittanceSummary]) -> [PrimaryRemittanceSummaryView] {
        var views: [PrimaryRemittanceSummaryView] = []
        for item in items {
            views.append(toPrimaryRemittanceSummaryView(item))
        }
        return views
    }

    static func sumPrimaryRemittanceSummaryView(_ view: PrimaryRemittanceSummaryView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRefills) + Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
