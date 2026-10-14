import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim segment is in its life cycle.
    enum ClaimSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One claim segment, with what the planners need to act on it.
    final class ClaimSegment {
        var code: String
        var label: String
        var visitMinutes: Int
        var ceiling: Double
        var patientRef: String
        var limit: Int
        var durationMinutes: Int
        var startsAt: Int
        var status: ClaimSegmentStatus

        init(code: String, label: String, visitMinutes: Int, ceiling: Double, patientRef: String, limit: Int, durationMinutes: Int, startsAt: Int, status: ClaimSegmentStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ClaimSegmentStatus) -> Bool {
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
                return next == ClaimSegmentStatus.failed
            case .running:
                return next == ClaimSegmentStatus.done
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

        func moveTo(_ next: ClaimSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(visitMinutes) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimSegment {
            return ClaimSegment(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                patientRef: patientRef,
                limit: limit,
                durationMinutes: durationMinutes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim segment in status new.
    static func newClaimSegment(_ code: String, label: String) -> ClaimSegment {
        return ClaimSegment(
            code: code,
            label: label,
            visitMinutes: 0,
            ceiling: 0.0,
            patientRef: "",
            limit: 0,
            durationMinutes: 0,
            startsAt: 0,
            status: ClaimSegmentStatus.new
        )
    }
}
