import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance assignment.
    final class RemittanceAssignmentView {
        var codeText: String
        var name: String
        var allergyText: String
        var refills: String
        var segment: String
        var checksum: String
        var rate: String
        var statusLabel: String

        init(codeText: String, name: String, allergyText: String, refills: String, segment: String, checksum: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.allergyText = allergyText
            self.refills = refills
            self.segment = segment
            self.checksum = checksum
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceAssignmentView(_ item: RemittanceAssignment) -> RemittanceAssignmentView {
        return RemittanceAssignmentView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            allergyText: item.allergy,
            refills: String(item.refills),
            segment: item.segment,
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceAssignmentViews(_ items: [RemittanceAssignment]) -> [RemittanceAssignmentView] {
        var views: [RemittanceAssignmentView] = []
        for item in items {
            views.append(toRemittanceAssignmentView(item))
        }
        return views
    }

    static func sumRemittanceAssignmentView(_ view: RemittanceAssignmentView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRefills) + parsedRate
    }
}
