import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched denial policy.
    final class BatchedDenialPolicyView {
        var code: String
        var titleText: String
        var bedText: String
        var active: String
        var capacity: String
        var statusLabel: String

        init(code: String, titleText: String, bedText: String, active: String, capacity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.bedText = bedText
            self.active = active
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDenialPolicyView(_ item: BatchedDenialPolicy) -> BatchedDenialPolicyView {
        return BatchedDenialPolicyView(
            code: item.code,
            titleText: item.title,
            bedText: item.bed,
            active: "\(item.active)",
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDenialPolicyViews(_ items: [BatchedDenialPolicy]) -> [BatchedDenialPolicyView] {
        var views: [BatchedDenialPolicyView] = []
        for item in items {
            views.append(toBatchedDenialPolicyView(item))
        }
        return views
    }

    static func sumBatchedDenialPolicyView(_ view: BatchedDenialPolicyView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
