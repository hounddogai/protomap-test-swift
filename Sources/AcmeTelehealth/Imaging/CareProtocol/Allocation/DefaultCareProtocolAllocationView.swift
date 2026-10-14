import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default care protocol allocation.
    final class DefaultCareProtocolAllocationView {
        var code: String
        var title: String
        var diagnosisCodeText: String
        var quantity: String
        var capacity: String
        var refillsText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCodeText: String, quantity: String, capacity: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCodeText = diagnosisCodeText
            self.quantity = quantity
            self.capacity = capacity
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolAllocationView(_ item: DefaultCareProtocolAllocation) -> DefaultCareProtocolAllocationView {
        return DefaultCareProtocolAllocationView(
            code: item.code,
            title: item.title,
            diagnosisCodeText: item.diagnosisCode,
            quantity: String(item.quantity),
            capacity: String(item.capacity),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolAllocationViews(_ items: [DefaultCareProtocolAllocation]) -> [DefaultCareProtocolAllocationView] {
        var views: [DefaultCareProtocolAllocationView] = []
        for item in items {
            views.append(toDefaultCareProtocolAllocationView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolAllocationView(_ view: DefaultCareProtocolAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCapacity) + Double(parsedRefills)
    }
}
