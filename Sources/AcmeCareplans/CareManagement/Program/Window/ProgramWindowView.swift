import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program window.
    final class ProgramWindowView {
        var code: String
        var name: String
        var amount: String
        var unit: String
        var maximumText: String
        var retriesText: String
        var updatedAtText: String
        var label: String
        var visible: String
        var startsAt: String
        var statusLabel: String

        init(code: String, name: String, amount: String, unit: String, maximumText: String, retriesText: String, updatedAtText: String, label: String, visible: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.amount = amount
            self.unit = unit
            self.maximumText = maximumText
            self.retriesText = retriesText
            self.updatedAtText = updatedAtText
            self.label = label
            self.visible = visible
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toProgramWindowView(_ item: ProgramWindow) -> ProgramWindowView {
        return ProgramWindowView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            amount: String(format: "%.2f", item.amount),
            unit: item.unit,
            maximumText: String(format: "%.2f", item.maximum),
            retriesText: String(item.retries),
            updatedAtText: String(item.updatedAt),
            label: item.label,
            visible: "\(item.visible)",
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramWindowViews(_ items: [ProgramWindow]) -> [ProgramWindowView] {
        var views: [ProgramWindowView] = []
        for item in items {
            views.append(toProgramWindowView(item))
        }
        return views
    }

    static func sumProgramWindowView(_ view: ProgramWindowView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedAmount + parsedMaximum + Double(parsedRetries)
    }
}
