import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool request is in its life cycle.
    enum FloatPoolRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A float pool request as the float pool team keeps it.
    final class FloatPoolRequest {
        var code: String
        var name: String
        var durationMinutes: Int
        var diagnosisCode: String
        var country: String
        var visible: Bool
        var description: String
        var discount: Double
        var channel: String
        var status: FloatPoolRequestStatus

        init(code: String, name: String, durationMinutes: Int, diagnosisCode: String, country: String, visible: Bool, description: String, discount: Double, channel: String, status: FloatPoolRequestStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.country = country
            self.visible = visible
            self.description = description
            self.discount = discount
            self.channel = channel
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

        func canMoveTo(_ next: FloatPoolRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FloatPoolRequestStatus.done
            case .running:
                return next == FloatPoolRequestStatus.done || next == FloatPoolRequestStatus.failed
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

        func moveTo(_ next: FloatPoolRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (discount * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolRequest {
            return FloatPoolRequest(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                country: country,
                visible: visible,
                description: description,
                discount: discount,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a float pool request in status new.
    static func newFloatPoolRequest(_ code: String, name: String) -> FloatPoolRequest {
        return FloatPoolRequest(
            code: code,
            name: name,
            durationMinutes: 0,
            diagnosisCode: "",
            country: "",
            visible: false,
            description: "",
            discount: 0.0,
            channel: "",
            status: FloatPoolRequestStatus.new
        )
    }
}
