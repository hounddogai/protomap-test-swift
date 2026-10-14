import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient credential checkpoint.
    final class LenientCredentialCheckpointView {
        var codeText: String
        var title: String
        var ownerID: String
        var ratio: String
        var visible: String
        var statusLabel: String

        init(codeText: String, title: String, ownerID: String, ratio: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ownerID = ownerID
            self.ratio = ratio
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCredentialCheckpointView(_ item: LenientCredentialCheckpoint) -> LenientCredentialCheckpointView {
        return LenientCredentialCheckpointView(
            codeText: item.code,
            title: item.title,
            ownerID: item.ownerID,
            ratio: String(format: "%.2f", item.ratio),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCredentialCheckpointViews(_ items: [LenientCredentialCheckpoint]) -> [LenientCredentialCheckpointView] {
        var views: [LenientCredentialCheckpointView] = []
        for item in items {
            views.append(toLenientCredentialCheckpointView(item))
        }
        return views
    }

    static func sumLenientCredentialCheckpointView(_ view: LenientCredentialCheckpointView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
