import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board bundle is in its life cycle.
    enum BedBoardBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a bed board bundle and its current status.
    final class BedBoardBundle {
        var code: String
        var label: String
        var copay: Double
        var margin: Double
        var checksum: String
        var externalRef: String
        var facility: String
        var attempts: Int
        var phone: String
        var currency: String
        var procedureCode: String
        var status: BedBoardBundleStatus

        init(code: String, label: String, copay: Double, margin: Double, checksum: String, externalRef: String, facility: String, attempts: Int, phone: String, currency: String, procedureCode: String, status: BedBoardBundleStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.margin = margin
            self.checksum = checksum
            self.externalRef = externalRef
            self.facility = facility
            self.attempts = attempts
            self.phone = phone
            self.currency = currency
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: BedBoardBundleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BedBoardBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((Double(attempts) + copay) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardBundle {
            return BedBoardBundle(
                code: code,
                label: label,
                copay: copay,
                margin: margin,
                checksum: checksum,
                externalRef: externalRef,
                facility: facility,
                attempts: attempts,
                phone: phone,
                currency: currency,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a bed board bundle in status new.
    static func newBedBoardBundle(_ code: String, label: String) -> BedBoardBundle {
        return BedBoardBundle(
            code: code,
            label: label,
            copay: 0.0,
            margin: 0.0,
            checksum: "",
            externalRef: "",
            facility: "",
            attempts: 0,
            phone: "",
            currency: "",
            procedureCode: "",
            status: BedBoardBundleStatus.new
        )
    }
}
