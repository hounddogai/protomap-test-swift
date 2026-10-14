import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read plan is in its life cycle.
    enum ReadPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One read plan, with what the planners need to act on it.
    final class ReadPlan {
        var code: String
        var title: String
        var procedureCode: String
        var threshold: Double
        var retries: Int
        var phone: String
        var dosageMg: Double
        var quantity: Int
        var floorValue: Double
        var expiresAt: Int
        var facility: String
        var status: ReadPlanStatus

        init(code: String, title: String, procedureCode: String, threshold: Double, retries: Int, phone: String, dosageMg: Double, quantity: Int, floorValue: Double, expiresAt: Int, facility: String, status: ReadPlanStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.retries = retries
            self.phone = phone
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.facility = facility
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

        func canMoveTo(_ next: ReadPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReadPlanStatus.ready || next == ReadPlanStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ReadPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((threshold + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ReadPlan {
            return ReadPlan(
                code: code,
                title: title,
                procedureCode: procedureCode,
                threshold: threshold,
                retries: retries,
                phone: phone,
                dosageMg: dosageMg,
                quantity: quantity,
                floorValue: floorValue,
                expiresAt: expiresAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a read plan in status idle.
    static func newReadPlan(_ code: String, title: String) -> ReadPlan {
        return ReadPlan(
            code: code,
            title: title,
            procedureCode: "",
            threshold: 0.0,
            retries: 0,
            phone: "",
            dosageMg: 0.0,
            quantity: 0,
            floorValue: 0.0,
            expiresAt: 0,
            facility: "",
            status: ReadPlanStatus.idle
        )
    }
}
