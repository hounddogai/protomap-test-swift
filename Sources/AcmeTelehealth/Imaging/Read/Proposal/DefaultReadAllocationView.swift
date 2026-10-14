import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default read allocation.
    final class DefaultReadAllocationView {
        var codeText: String
        var label: String
        var capacity: String
        var externalRef: String
        var versionText: String
        var phoneText: String
        var revision: String
        var patientRef: String
        var ward: String
        var description: String
        var statusLabel: String

        init(codeText: String, label: String, capacity: String, externalRef: String, versionText: String, phoneText: String, revision: String, patientRef: String, ward: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.capacity = capacity
            self.externalRef = externalRef
            self.versionText = versionText
            self.phoneText = phoneText
            self.revision = revision
            self.patientRef = patientRef
            self.ward = ward
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultReadAllocationView(_ item: DefaultReadAllocation) -> DefaultReadAllocationView {
        return DefaultReadAllocationView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            capacity: String(item.capacity),
            externalRef: item.externalRef,
            versionText: String(item.version),
            phoneText: item.phone,
            revision: String(item.revision),
            patientRef: item.patientRef,
            ward: item.ward,
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultReadAllocationViews(_ items: [DefaultReadAllocation]) -> [DefaultReadAllocationView] {
        var views: [DefaultReadAllocationView] = []
        for item in items {
            views.append(toDefaultReadAllocationView(item))
        }
        return views
    }

    static func sumDefaultReadAllocationView(_ view: DefaultReadAllocationView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVersion) + Double(parsedRevision)
    }
}
