import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback isolation group is in its life cycle.
    enum FallbackIsolationGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback isolation group and its current status.
    final class FallbackIsolationGroup {
        var code: String
        var label: String
        var specialty: String
        var expiresAt: Int
        var quantity: Int
        var endsAt: Int
        var notes: String
        var active: Bool
        var maximum: Double
        var visitMinutes: Int
        var segment: String
        var status: FallbackIsolationGroupStatus

        init(code: String, label: String, specialty: String, expiresAt: Int, quantity: Int, endsAt: Int, notes: String, active: Bool, maximum: Double, visitMinutes: Int, segment: String, status: FallbackIsolationGroupStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.endsAt = endsAt
            self.notes = notes
            self.active = active
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.segment = segment
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

        func canMoveTo(_ next: FallbackIsolationGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackIsolationGroupStatus.queued
            case .queued:
                return next == FallbackIsolationGroupStatus.done
            case .running:
                return next == FallbackIsolationGroupStatus.done || next == FallbackIsolationGroupStatus.failed
            case .done:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackIsolationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback isolation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback isolation group") \(code)"
        }

        func netLoad() -> Double {
            return ((maximum - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackIsolationGroup {
            return FallbackIsolationGroup(
                code: code,
                label: label,
                specialty: specialty,
                expiresAt: expiresAt,
                quantity: quantity,
                endsAt: endsAt,
                notes: notes,
                active: active,
                maximum: maximum,
                visitMinutes: visitMinutes,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback isolation group in status new.
    static func newFallbackIsolationGroup(_ code: String, label: String) -> FallbackIsolationGroup {
        return FallbackIsolationGroup(
            code: code,
            label: label,
            specialty: "",
            expiresAt: 0,
            quantity: 0,
            endsAt: 0,
            notes: "",
            active: false,
            maximum: 0.0,
            visitMinutes: 0,
            segment: "",
            status: FallbackIsolationGroupStatus.new
        )
    }
}
