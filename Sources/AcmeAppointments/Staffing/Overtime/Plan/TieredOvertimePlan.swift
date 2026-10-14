import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered overtime plan is in its life cycle.
    enum TieredOvertimePlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered overtime plan. Its code is unique within a tenant.
    final class TieredOvertimePlan {
        var code: String
        var name: String
        var tags: [String]
        var expiresAt: Int
        var label: String
        var ward: String
        var currency: String
        var description: String
        var capacity: Int
        var status: TieredOvertimePlanStatus

        init(code: String, name: String, tags: [String], expiresAt: Int, label: String, ward: String, currency: String, description: String, capacity: Int, status: TieredOvertimePlanStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.expiresAt = expiresAt
            self.label = label
            self.ward = ward
            self.currency = currency
            self.description = description
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredOvertimePlanStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredOvertimePlanStatus.queued || next == TieredOvertimePlanStatus.done
            case .queued:
                return next == TieredOvertimePlanStatus.running || next == TieredOvertimePlanStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredOvertimePlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOvertimePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered overtime plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return (Double(capacity) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredOvertimePlan {
            return TieredOvertimePlan(
                code: code,
                name: name,
                tags: tags,
                expiresAt: expiresAt,
                label: label,
                ward: ward,
                currency: currency,
                description: description,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered overtime plan in status new.
    static func newTieredOvertimePlan(_ code: String, name: String) -> TieredOvertimePlan {
        return TieredOvertimePlan(
            code: code,
            name: name,
            tags: [],
            expiresAt: 0,
            label: "",
            ward: "",
            currency: "",
            description: "",
            capacity: 0,
            status: TieredOvertimePlanStatus.new
        )
    }
}
