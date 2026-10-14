import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled care gap policy is in its life cycle.
    enum ScheduledCareGapPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled care gap policy. Its code is unique within a tenant.
    final class ScheduledCareGapPolicy {
        var code: String
        var name: String
        var pinned: Bool
        var quantity: Int
        var diagnosisCode: String
        var description: String
        var tags: [String]
        var source: String
        var category: String
        var windowDays: Int
        var status: ScheduledCareGapPolicyStatus

        init(code: String, name: String, pinned: Bool, quantity: Int, diagnosisCode: String, description: String, tags: [String], source: String, category: String, windowDays: Int, status: ScheduledCareGapPolicyStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.tags = tags
            self.source = source
            self.category = category
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCareGapPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledCareGapPolicyStatus.approved || next == ScheduledCareGapPolicyStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ScheduledCareGapPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareGapPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care gap policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((Double(windowDays) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareGapPolicy {
            return ScheduledCareGapPolicy(
                code: code,
                name: name,
                pinned: pinned,
                quantity: quantity,
                diagnosisCode: diagnosisCode,
                description: description,
                tags: tags,
                source: source,
                category: category,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled care gap policy in status proposed.
    static func newScheduledCareGapPolicy(_ code: String, name: String) -> ScheduledCareGapPolicy {
        return ScheduledCareGapPolicy(
            code: code,
            name: name,
            pinned: false,
            quantity: 0,
            diagnosisCode: "",
            description: "",
            tags: [],
            source: "",
            category: "",
            windowDays: 0,
            status: ScheduledCareGapPolicyStatus.proposed
        )
    }
}
