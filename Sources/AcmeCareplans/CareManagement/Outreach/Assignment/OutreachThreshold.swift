import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach threshold is in its life cycle.
    enum OutreachThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a outreach threshold and its current status.
    final class OutreachThreshold {
        var code: String
        var title: String
        var attributes: [String: String]
        var approved: Bool
        var limit: Int
        var specialty: String
        var ward: String
        var ceiling: Double
        var facility: String
        var windowDays: Int
        var weight: Double
        var status: OutreachThresholdStatus

        init(code: String, title: String, attributes: [String: String], approved: Bool, limit: Int, specialty: String, ward: String, ceiling: Double, facility: String, windowDays: Int, weight: Double, status: OutreachThresholdStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.approved = approved
            self.limit = limit
            self.specialty = specialty
            self.ward = ward
            self.ceiling = ceiling
            self.facility = facility
            self.windowDays = windowDays
            self.weight = weight
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

        func canMoveTo(_ next: OutreachThresholdStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
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
                case .done, .failed:
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

        func moveTo(_ next: OutreachThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return (Double(windowDays) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> OutreachThreshold {
            return OutreachThreshold(
                code: code,
                title: title,
                attributes: attributes,
                approved: approved,
                limit: limit,
                specialty: specialty,
                ward: ward,
                ceiling: ceiling,
                facility: facility,
                windowDays: windowDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a outreach threshold in status new.
    static func newOutreachThreshold(_ code: String, title: String) -> OutreachThreshold {
        return OutreachThreshold(
            code: code,
            title: title,
            attributes: [:],
            approved: false,
            limit: 0,
            specialty: "",
            ward: "",
            ceiling: 0.0,
            facility: "",
            windowDays: 0,
            weight: 0.0,
            status: OutreachThresholdStatus.new
        )
    }
}
