import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap metrics through their life cycle and keeps a journal of what it did.
    final class CareGapMetricDesk {
        var store: any CareGapMetricStore
        var validator: CareGapMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapMetricStore, validator: CareGapMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapMetricStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapMetricStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCareGapMetricDesk(_ store: any CareGapMetricStore, clock: any Kit.Clocks.Clock) -> CareGapMetricDesk {
        return CareGapMetricDesk(store: store, validator: defaultCareGapMetricValidator(), clock: clock, journal: [])
    }
}
