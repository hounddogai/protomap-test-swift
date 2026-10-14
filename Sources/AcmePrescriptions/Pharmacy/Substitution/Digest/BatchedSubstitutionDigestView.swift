import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched substitution digest.
    final class BatchedSubstitutionDigestView {
        var code: String
        var title: String
        var externalRefText: String
        var createdAtText: String
        var refills: String
        var floorValue: String
        var wardText: String
        var clinicianID: String
        var channelText: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, createdAtText: String, refills: String, floorValue: String, wardText: String, clinicianID: String, channelText: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.createdAtText = createdAtText
            self.refills = refills
            self.floorValue = floorValue
            self.wardText = wardText
            self.clinicianID = clinicianID
            self.channelText = channelText
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSubstitutionDigestView(_ item: BatchedSubstitutionDigest) -> BatchedSubstitutionDigestView {
        return BatchedSubstitutionDigestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            externalRefText: item.externalRef,
            createdAtText: String(item.createdAt),
            refills: String(item.refills),
            floorValue: String(format: "%.2f", item.floorValue),
            wardText: item.ward,
            clinicianID: item.clinicianID,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSubstitutionDigestViews(_ items: [BatchedSubstitutionDigest]) -> [BatchedSubstitutionDigestView] {
        var views: [BatchedSubstitutionDigestView] = []
        for item in items {
            views.append(toBatchedSubstitutionDigestView(item))
        }
        return views
    }

    static func sumBatchedSubstitutionDigestView(_ view: BatchedSubstitutionDigestView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRefills) + parsedFloorValue
    }
}
