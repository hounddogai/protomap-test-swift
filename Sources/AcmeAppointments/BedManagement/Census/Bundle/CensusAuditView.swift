import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census audit.
    final class CensusAuditView {
        var code: String
        var name: String
        var capacityText: String
        var sequence: String
        var quantity: String
        var acuityText: String
        var copay: String
        var cost: String
        var externalRef: String
        var country: String
        var refills: String
        var statusLabel: String

        init(code: String, name: String, capacityText: String, sequence: String, quantity: String, acuityText: String, copay: String, cost: String, externalRef: String, country: String, refills: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacityText = capacityText
            self.sequence = sequence
            self.quantity = quantity
            self.acuityText = acuityText
            self.copay = copay
            self.cost = cost
            self.externalRef = externalRef
            self.country = country
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toCensusAuditView(_ item: CensusAudit) -> CensusAuditView {
        return CensusAuditView(
            code: item.code,
            name: item.name,
            capacityText: String(item.capacity),
            sequence: String(item.sequence),
            quantity: String(item.quantity),
            acuityText: String(item.acuity),
            copay: String(format: "%.2f", item.copay),
            cost: String(format: "%.2f", item.cost),
            externalRef: item.externalRef,
            country: item.country,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusAuditViews(_ items: [CensusAudit]) -> [CensusAuditView] {
        var views: [CensusAuditView] = []
        for item in items {
            views.append(toCensusAuditView(item))
        }
        return views
    }

    static func sumCensusAuditView(_ view: CensusAuditView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedCapacity) + Double(parsedSequence) + Double(parsedQuantity)
    }
}
