import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary score is in its life cycle.
    enum FormularyScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One formulary score, with what the planners need to act on it.
    final class FormularyScore {
        var code: String
        var label: String
        var dosageMg: Double
        var pinned: Bool
        var version: Int
        var ratio: Double
        var notes: String
        var floorValue: Double
        var status: FormularyScoreStatus

        init(code: String, label: String, dosageMg: Double, pinned: Bool, version: Int, ratio: Double, notes: String, floorValue: Double, status: FormularyScoreStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.pinned = pinned
            self.version = version
            self.ratio = ratio
            self.notes = notes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: FormularyScoreStatus) -> Bool {
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
                return next == FormularyScoreStatus.running || next == FormularyScoreStatus.failed
            case .running:
                return next == FormularyScoreStatus.failed
            case .done:
                return next == FormularyScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return (dosageMg * floorValue * 100).rounded() / 100
        }

        func copyValue() -> FormularyScore {
            return FormularyScore(
                code: code,
                label: label,
                dosageMg: dosageMg,
                pinned: pinned,
                version: version,
                ratio: ratio,
                notes: notes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary score in status new.
    static func newFormularyScore(_ code: String, label: String) -> FormularyScore {
        return FormularyScore(
            code: code,
            label: label,
            dosageMg: 0.0,
            pinned: false,
            version: 0,
            ratio: 0.0,
            notes: "",
            floorValue: 0.0,
            status: FormularyScoreStatus.new
        )
    }
}
