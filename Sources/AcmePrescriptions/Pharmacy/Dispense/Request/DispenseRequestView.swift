import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense request.
    final class DispenseRequestView {
        var code: String
        var name: String
        var phone: String
        var weightText: String
        var statusLabel: String

        init(code: String, name: String, phone: String, weightText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phone = phone
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseRequestView(_ item: DispenseRequest) -> DispenseRequestView {
        return DispenseRequestView(
            code: item.code,
            name: item.name,
            phone: item.phone,
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseRequestViews(_ items: [DispenseRequest]) -> [DispenseRequestView] {
        var views: [DispenseRequestView] = []
        for item in items {
            views.append(toDispenseRequestView(item))
        }
        return views
    }

    static func sumDispenseRequestView(_ view: DispenseRequestView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
