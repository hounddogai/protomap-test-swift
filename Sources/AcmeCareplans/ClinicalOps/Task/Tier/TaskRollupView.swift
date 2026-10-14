import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task rollup.
    final class TaskRollupView {
        var codeText: String
        var titleText: String
        var dosageMg: String
        var windowDays: String
        var startsAt: String
        var phoneText: String
        var expiresAt: String
        var approved: String
        var statusLabel: String

        init(codeText: String, titleText: String, dosageMg: String, windowDays: String, startsAt: String, phoneText: String, expiresAt: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.phoneText = phoneText
            self.expiresAt = expiresAt
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toTaskRollupView(_ item: TaskRollup) -> TaskRollupView {
        return TaskRollupView(
            codeText: item.code,
            titleText: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            windowDays: String(item.windowDays),
            startsAt: String(item.startsAt),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            expiresAt: String(item.expiresAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskRollupViews(_ items: [TaskRollup]) -> [TaskRollupView] {
        var views: [TaskRollupView] = []
        for item in items {
            views.append(toTaskRollupView(item))
        }
        return views
    }

    static func sumTaskRollupView(_ view: TaskRollupView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDosageMg + Double(parsedWindowDays) + Double(parsedStartsAt)
    }
}
