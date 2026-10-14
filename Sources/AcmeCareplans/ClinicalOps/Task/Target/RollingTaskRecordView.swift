import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling task record.
    final class RollingTaskRecordView {
        var code: String
        var name: String
        var phoneText: String
        var weight: String
        var source: String
        var ownerID: String
        var revision: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, phoneText: String, weight: String, source: String, ownerID: String, revision: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phoneText = phoneText
            self.weight = weight
            self.source = source
            self.ownerID = ownerID
            self.revision = revision
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toRollingTaskRecordView(_ item: RollingTaskRecord) -> RollingTaskRecordView {
        return RollingTaskRecordView(
            code: item.code,
            name: item.name,
            phoneText: item.phone,
            weight: String(format: "%.2f", item.weight),
            source: item.source,
            ownerID: item.ownerID,
            revision: String(item.revision),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingTaskRecordViews(_ items: [RollingTaskRecord]) -> [RollingTaskRecordView] {
        var views: [RollingTaskRecordView] = []
        for item in items {
            views.append(toRollingTaskRecordView(item))
        }
        return views
    }

    static func sumRollingTaskRecordView(_ view: RollingTaskRecordView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedWeight + Double(parsedRevision) + Double(parsedRetries)
    }
}
