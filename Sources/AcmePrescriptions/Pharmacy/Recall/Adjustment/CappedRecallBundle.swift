import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped recall bundle is in its life cycle.
    enum CappedRecallBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped recall bundle as the recall team keeps it.
    final class CappedRecallBundle {
        var code: String
        var name: String
        var retries: Int
        var encounterID: String
        var country: String
        var title: String
        var approved: Bool
        var region: String
        var rate: Double
        var source: String
        var segment: String
        var status: CappedRecallBundleStatus

        init(code: String, name: String, retries: Int, encounterID: String, country: String, title: String, approved: Bool, region: String, rate: Double, source: String, segment: String, status: CappedRecallBundleStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.encounterID = encounterID
            self.country = country
            self.title = title
            self.approved = approved
            self.region = region
            self.rate = rate
            self.source = source
            self.segment = segment
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

        func canMoveTo(_ next: CappedRecallBundleStatus) -> Bool {
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
                return next == CappedRecallBundleStatus.done
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

        func moveTo(_ next: CappedRecallBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped recall bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped recall bundle") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(retries) * rate * 100).rounded() / 100
        }

        func copyValue() -> CappedRecallBundle {
            return CappedRecallBundle(
                code: code,
                name: name,
                retries: retries,
                encounterID: encounterID,
                country: country,
                title: title,
                approved: approved,
                region: region,
                rate: rate,
                source: source,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped recall bundle in status new.
    static func newCappedRecallBundle(_ code: String, name: String) -> CappedRecallBundle {
        return CappedRecallBundle(
            code: code,
            name: name,
            retries: 0,
            encounterID: "",
            country: "",
            title: "",
            approved: false,
            region: "",
            rate: 0.0,
            source: "",
            segment: "",
            status: CappedRecallBundleStatus.new
        )
    }
}
