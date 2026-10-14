import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff group is in its life cycle.
    enum HandoffGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a handoff group and its current status.
    final class HandoffGroup {
        var code: String
        var title: String
        var specialty: String
        var expiresAt: Int
        var floorValue: Double
        var reviewer: String
        var status: HandoffGroupStatus

        init(code: String, title: String, specialty: String, expiresAt: Int, floorValue: Double, reviewer: String, status: HandoffGroupStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.reviewer = reviewer
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

        func canMoveTo(_ next: HandoffGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == HandoffGroupStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: HandoffGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("handoff group") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((floorValue - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffGroup {
            return HandoffGroup(
                code: code,
                title: title,
                specialty: specialty,
                expiresAt: expiresAt,
                floorValue: floorValue,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff group in status new.
    static func newHandoffGroup(_ code: String, title: String) -> HandoffGroup {
        return HandoffGroup(
            code: code,
            title: title,
            specialty: "",
            expiresAt: 0,
            floorValue: 0.0,
            reviewer: "",
            status: HandoffGroupStatus.new
        )
    }
}
