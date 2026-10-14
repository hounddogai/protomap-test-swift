import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global remittance exception.
    final class GlobalRemittanceExceptionView {
        var code: String
        var name: String
        var capacityText: String
        var activeText: String
        var facilityText: String
        var revisionText: String
        var externalRef: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, capacityText: String, activeText: String, facilityText: String, revisionText: String, externalRef: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacityText = capacityText
            self.activeText = activeText
            self.facilityText = facilityText
            self.revisionText = revisionText
            self.externalRef = externalRef
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRemittanceExceptionView(_ item: GlobalRemittanceException) -> GlobalRemittanceExceptionView {
        return GlobalRemittanceExceptionView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            capacityText: String(item.capacity),
            activeText: "\(item.active)",
            facilityText: item.facility,
            revisionText: String(item.revision),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRemittanceExceptionViews(_ items: [GlobalRemittanceException]) -> [GlobalRemittanceExceptionView] {
        var views: [GlobalRemittanceExceptionView] = []
        for item in items {
            views.append(toGlobalRemittanceExceptionView(item))
        }
        return views
    }

    static func sumGlobalRemittanceExceptionView(_ view: GlobalRemittanceExceptionView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRevision) + Double(parsedCreatedAt)
    }
}
