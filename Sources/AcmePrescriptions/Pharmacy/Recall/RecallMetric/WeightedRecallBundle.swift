import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted recall bundle is in its life cycle.
    enum WeightedRecallBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One weighted recall bundle, with what the planners need to act on it.
    final class WeightedRecallBundle {
        var code: String
        var title: String
        var createdAt: Int
        var name: String
        var active: Bool
        var clinicianID: String
        var description: String
        var amount: Double
        var tags: [String]
        var status: WeightedRecallBundleStatus

        init(code: String, title: String, createdAt: Int, name: String, active: Bool, clinicianID: String, description: String, amount: Double, tags: [String], status: WeightedRecallBundleStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.name = name
            self.active = active
            self.clinicianID = clinicianID
            self.description = description
            self.amount = amount
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRecallBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedRecallBundleStatus.ready || next == WeightedRecallBundleStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WeightedRecallBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRecallBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted recall bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted recall bundle") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (amount * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRecallBundle {
            return WeightedRecallBundle(
                code: code,
                title: title,
                createdAt: createdAt,
                name: name,
                active: active,
                clinicianID: clinicianID,
                description: description,
                amount: amount,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted recall bundle in status idle.
    static func newWeightedRecallBundle(_ code: String, title: String) -> WeightedRecallBundle {
        return WeightedRecallBundle(
            code: code,
            title: title,
            createdAt: 0,
            name: "",
            active: false,
            clinicianID: "",
            description: "",
            amount: 0.0,
            tags: [],
            status: WeightedRecallBundleStatus.idle
        )
    }
}
