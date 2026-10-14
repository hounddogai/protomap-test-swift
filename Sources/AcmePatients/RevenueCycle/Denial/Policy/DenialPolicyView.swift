import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial policy.
    final class DenialPolicyView {
        var codeText: String
        var name: String
        var ownerID: String
        var region: String
        var maximum: String
        var patientRef: String
        var checksumText: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, name: String, ownerID: String, region: String, maximum: String, patientRef: String, checksumText: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ownerID = ownerID
            self.region = region
            self.maximum = maximum
            self.patientRef = patientRef
            self.checksumText = checksumText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toDenialPolicyView(_ item: DenialPolicy) -> DenialPolicyView {
        return DenialPolicyView(
            codeText: item.code,
            name: item.name,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            region: Kit.Text.truncate(item.region, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            patientRef: item.patientRef,
            checksumText: item.checksum,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialPolicyViews(_ items: [DenialPolicy]) -> [DenialPolicyView] {
        var views: [DenialPolicyView] = []
        for item in items {
            views.append(toDenialPolicyView(item))
        }
        return views
    }

    static func sumDenialPolicyView(_ view: DenialPolicyView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedMaximum + Double(parsedCapacity)
    }
}
