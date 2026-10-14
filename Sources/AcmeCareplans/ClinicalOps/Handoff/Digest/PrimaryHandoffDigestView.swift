import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary handoff digest.
    final class PrimaryHandoffDigestView {
        var code: String
        var title: String
        var visitMinutesText: String
        var channel: String
        var dosageMg: String
        var capacity: String
        var createdAtText: String
        var ward: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, channel: String, dosageMg: String, capacity: String, createdAtText: String, ward: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.channel = channel
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.createdAtText = createdAtText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryHandoffDigestView(_ item: PrimaryHandoffDigest) -> PrimaryHandoffDigestView {
        return PrimaryHandoffDigestView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            channel: item.channel,
            dosageMg: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            createdAtText: String(item.createdAt),
            ward: Kit.Text.truncate(item.ward, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryHandoffDigestViews(_ items: [PrimaryHandoffDigest]) -> [PrimaryHandoffDigestView] {
        var views: [PrimaryHandoffDigestView] = []
        for item in items {
            views.append(toPrimaryHandoffDigestView(item))
        }
        return views
    }

    static func sumPrimaryHandoffDigestView(_ view: PrimaryHandoffDigestView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedVisitMinutes) + parsedDosageMg + Double(parsedCapacity)
    }
}
