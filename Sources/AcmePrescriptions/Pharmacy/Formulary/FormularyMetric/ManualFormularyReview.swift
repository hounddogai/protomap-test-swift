import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary review is in its life cycle.
    enum ManualFormularyReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual formulary review. Its code is unique within a tenant.
    final class ManualFormularyReview {
        var code: String
        var name: String
        var expiresAt: Int
        var patientRef: String
        var visible: Bool
        var floorValue: Double
        var description: String
        var status: ManualFormularyReviewStatus

        init(code: String, name: String, expiresAt: Int, patientRef: String, visible: Bool, floorValue: Double, description: String, status: ManualFormularyReviewStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.visible = visible
            self.floorValue = floorValue
            self.description = description
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

        func canMoveTo(_ next: ManualFormularyReviewStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualFormularyReviewStatus.done || next == ManualFormularyReviewStatus.failed
            case .running:
                return next == ManualFormularyReviewStatus.done || next == ManualFormularyReviewStatus.failed
            case .done:
                return next == ManualFormularyReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualFormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(expiresAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyReview {
            return ManualFormularyReview(
                code: code,
                name: name,
                expiresAt: expiresAt,
                patientRef: patientRef,
                visible: visible,
                floorValue: floorValue,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual formulary review in status new.
    static func newManualFormularyReview(_ code: String, name: String) -> ManualFormularyReview {
        return ManualFormularyReview(
            code: code,
            name: name,
            expiresAt: 0,
            patientRef: "",
            visible: false,
            floorValue: 0.0,
            description: "",
            status: ManualFormularyReviewStatus.new
        )
    }
}
