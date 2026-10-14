import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global read digest is in its life cycle.
    enum GlobalReadDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global read digest and its current status.
    final class GlobalReadDigest {
        var code: String
        var name: String
        var externalRef: String
        var ward: String
        var diagnosisCode: String
        var visitMinutes: Int
        var ceiling: Double
        var unit: String
        var minimum: Double
        var status: GlobalReadDigestStatus

        init(code: String, name: String, externalRef: String, ward: String, diagnosisCode: String, visitMinutes: Int, ceiling: Double, unit: String, minimum: Double, status: GlobalReadDigestStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.unit = unit
            self.minimum = minimum
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

        func canMoveTo(_ next: GlobalReadDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalReadDigestStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalReadDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReadDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global read digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global read digest") \(code)"
        }

        func projectedTotal() -> Double {
            return (ceiling * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReadDigest {
            return GlobalReadDigest(
                code: code,
                name: name,
                externalRef: externalRef,
                ward: ward,
                diagnosisCode: diagnosisCode,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                unit: unit,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global read digest in status idle.
    static func newGlobalReadDigest(_ code: String, name: String) -> GlobalReadDigest {
        return GlobalReadDigest(
            code: code,
            name: name,
            externalRef: "",
            ward: "",
            diagnosisCode: "",
            visitMinutes: 0,
            ceiling: 0.0,
            unit: "",
            minimum: 0.0,
            status: GlobalReadDigestStatus.idle
        )
    }
}
