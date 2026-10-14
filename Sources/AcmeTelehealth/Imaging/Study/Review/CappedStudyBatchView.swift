import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped study batch.
    final class CappedStudyBatchView {
        var code: String
        var name: String
        var windowDaysText: String
        var versionText: String
        var payer: String
        var retries: String
        var revision: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, name: String, windowDaysText: String, versionText: String, payer: String, retries: String, revision: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDaysText = windowDaysText
            self.versionText = versionText
            self.payer = payer
            self.retries = retries
            self.revision = revision
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedStudyBatchView(_ item: CappedStudyBatch) -> CappedStudyBatchView {
        return CappedStudyBatchView(
            code: item.code,
            name: item.name,
            windowDaysText: String(item.windowDays),
            versionText: String(item.version),
            payer: item.payer,
            retries: String(item.retries),
            revision: String(item.revision),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedStudyBatchViews(_ items: [CappedStudyBatch]) -> [CappedStudyBatchView] {
        var views: [CappedStudyBatchView] = []
        for item in items {
            views.append(toCappedStudyBatchView(item))
        }
        return views
    }

    static func sumCappedStudyBatchView(_ view: CappedStudyBatchView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedVersion) + Double(parsedRetries)
    }
}
