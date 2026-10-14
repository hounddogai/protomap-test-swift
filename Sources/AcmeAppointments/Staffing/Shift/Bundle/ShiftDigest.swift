import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift digest is in its life cycle.
    enum ShiftDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A shift digest. Its code is unique within a tenant.
    final class ShiftDigest {
        var code: String
        var label: String
        var visitMinutes: Int
        var category: String
        var createdAt: Int
        var specialty: String
        var priority: Int
        var threshold: Double
        var dosageMg: Double
        var procedureCode: String
        var visible: Bool
        var status: ShiftDigestStatus

        init(code: String, label: String, visitMinutes: Int, category: String, createdAt: Int, specialty: String, priority: Int, threshold: Double, dosageMg: Double, procedureCode: String, visible: Bool, status: ShiftDigestStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.category = category
            self.createdAt = createdAt
            self.specialty = specialty
            self.priority = priority
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.visible = visible
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

        func canMoveTo(_ next: ShiftDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == ShiftDigestStatus.failed
            case .queued:
                return next == ShiftDigestStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ShiftDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(createdAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> ShiftDigest {
            return ShiftDigest(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                category: category,
                createdAt: createdAt,
                specialty: specialty,
                priority: priority,
                threshold: threshold,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a shift digest in status new.
    static func newShiftDigest(_ code: String, label: String) -> ShiftDigest {
        return ShiftDigest(
            code: code,
            label: label,
            visitMinutes: 0,
            category: "",
            createdAt: 0,
            specialty: "",
            priority: 0,
            threshold: 0.0,
            dosageMg: 0.0,
            procedureCode: "",
            visible: false,
            status: ShiftDigestStatus.new
        )
    }
}
