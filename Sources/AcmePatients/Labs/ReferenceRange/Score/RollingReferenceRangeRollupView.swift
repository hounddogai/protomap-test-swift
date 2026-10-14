import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling reference range rollup.
    final class RollingReferenceRangeRollupView {
        var code: String
        var label: String
        var procedureCode: String
        var graceDaysText: String
        var timezone: String
        var facilityText: String
        var budget: String
        var checksumText: String
        var retries: String
        var attemptsText: String
        var revision: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, graceDaysText: String, timezone: String, facilityText: String, budget: String, checksumText: String, retries: String, attemptsText: String, revision: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.graceDaysText = graceDaysText
            self.timezone = timezone
            self.facilityText = facilityText
            self.budget = budget
            self.checksumText = checksumText
            self.retries = retries
            self.attemptsText = attemptsText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toRollingReferenceRangeRollupView(_ item: RollingReferenceRangeRollup) -> RollingReferenceRangeRollupView {
        return RollingReferenceRangeRollupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            procedureCode: item.procedureCode,
            graceDaysText: String(item.graceDays),
            timezone: item.timezone,
            facilityText: item.facility,
            budget: String(format: "%.2f", item.budget),
            checksumText: item.checksum,
            retries: String(item.retries),
            attemptsText: String(item.attempts),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingReferenceRangeRollupViews(_ items: [RollingReferenceRangeRollup]) -> [RollingReferenceRangeRollupView] {
        var views: [RollingReferenceRangeRollupView] = []
        for item in items {
            views.append(toRollingReferenceRangeRollupView(item))
        }
        return views
    }

    static func sumRollingReferenceRangeRollupView(_ view: RollingReferenceRangeRollupView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + parsedBudget + Double(parsedRetries)
    }
}
