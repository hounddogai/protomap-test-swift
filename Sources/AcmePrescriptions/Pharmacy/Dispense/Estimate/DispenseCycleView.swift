import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense cycle.
    final class DispenseCycleView {
        var code: String
        var title: String
        var copayText: String
        var archivedText: String
        var capacityText: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, copayText: String, archivedText: String, capacityText: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copayText = copayText
            self.archivedText = archivedText
            self.capacityText = capacityText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseCycleView(_ item: DispenseCycle) -> DispenseCycleView {
        return DispenseCycleView(
            code: item.code,
            title: item.title,
            copayText: String(format: "%.2f", item.copay),
            archivedText: "\(item.archived)",
            capacityText: String(item.capacity),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseCycleViews(_ items: [DispenseCycle]) -> [DispenseCycleView] {
        var views: [DispenseCycleView] = []
        for item in items {
            views.append(toDispenseCycleView(item))
        }
        return views
    }

    static func sumDispenseCycleView(_ view: DispenseCycleView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCopay + Double(parsedCapacity)
    }
}
