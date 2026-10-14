import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation group.
    final class RevocationGroupView {
        var code: String
        var label: String
        var diagnosisCode: String
        var quantity: String
        var wardText: String
        var retriesText: String
        var cost: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, quantity: String, wardText: String, retriesText: String, cost: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.wardText = wardText
            self.retriesText = retriesText
            self.cost = cost
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationGroupView(_ item: RevocationGroup) -> RevocationGroupView {
        return RevocationGroupView(
            code: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            quantity: String(item.quantity),
            wardText: item.ward,
            retriesText: String(item.retries),
            cost: String(format: "%.2f", item.cost),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationGroupViews(_ items: [RevocationGroup]) -> [RevocationGroupView] {
        var views: [RevocationGroupView] = []
        for item in items {
            views.append(toRevocationGroupView(item))
        }
        return views
    }

    static func sumRevocationGroupView(_ view: RevocationGroupView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRetries) + parsedCost
    }
}
