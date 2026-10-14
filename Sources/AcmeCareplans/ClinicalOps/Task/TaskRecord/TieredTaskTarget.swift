import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task target is in its life cycle.
    enum TieredTaskTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered task target. Its code is unique within a tenant.
    final class TieredTaskTarget {
        var code: String
        var name: String
        var endsAt: Int
        var bed: String
        var contactEmail: String
        var limit: Int
        var facility: String
        var tags: [String]
        var budget: Double
        var quantity: Int
        var status: TieredTaskTargetStatus

        init(code: String, name: String, endsAt: Int, bed: String, contactEmail: String, limit: Int, facility: String, tags: [String], budget: Double, quantity: Int, status: TieredTaskTargetStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.bed = bed
            self.contactEmail = contactEmail
            self.limit = limit
            self.facility = facility
            self.tags = tags
            self.budget = budget
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredTaskTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredTaskTargetStatus.done || next == TieredTaskTargetStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredTaskTargetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTaskTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered task target") \(code)"
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
            return ((Double(endsAt) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TieredTaskTarget {
            return TieredTaskTarget(
                code: code,
                name: name,
                endsAt: endsAt,
                bed: bed,
                contactEmail: contactEmail,
                limit: limit,
                facility: facility,
                tags: tags,
                budget: budget,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered task target in status new.
    static func newTieredTaskTarget(_ code: String, name: String) -> TieredTaskTarget {
        return TieredTaskTarget(
            code: code,
            name: name,
            endsAt: 0,
            bed: "",
            contactEmail: "",
            limit: 0,
            facility: "",
            tags: [],
            budget: 0.0,
            quantity: 0,
            status: TieredTaskTargetStatus.new
        )
    }
}
