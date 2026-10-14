import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback reference range batch.
    final class FallbackReferenceRangeBatchView {
        var codeText: String
        var title: String
        var label: String
        var externalRef: String
        var refills: String
        var nameText: String
        var statusLabel: String

        init(codeText: String, title: String, label: String, externalRef: String, refills: String, nameText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.label = label
            self.externalRef = externalRef
            self.refills = refills
            self.nameText = nameText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackReferenceRangeBatchView(_ item: FallbackReferenceRangeBatch) -> FallbackReferenceRangeBatchView {
        return FallbackReferenceRangeBatchView(
            codeText: item.code,
            title: item.title,
            label: item.label,
            externalRef: item.externalRef,
            refills: String(item.refills),
            nameText: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackReferenceRangeBatchViews(_ items: [FallbackReferenceRangeBatch]) -> [FallbackReferenceRangeBatchView] {
        var views: [FallbackReferenceRangeBatchView] = []
        for item in items {
            views.append(toFallbackReferenceRangeBatchView(item))
        }
        return views
    }

    static func sumFallbackReferenceRangeBatchView(_ view: FallbackReferenceRangeBatchView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
