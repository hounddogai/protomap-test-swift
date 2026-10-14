import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal disclosure cycles through their life cycle and keeps a journal of what it did.
    final class SeasonalDisclosureCycleService {
        var store: any SeasonalDisclosureCycleStore
        var validator: SeasonalDisclosureCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalDisclosureCycleStore, validator: SeasonalDisclosureCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal disclosure cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalDisclosureCycleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalDisclosureCycleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newSeasonalDisclosureCycleService(_ store: any SeasonalDisclosureCycleStore, clock: any Kit.Clocks.Clock) -> SeasonalDisclosureCycleService {
        return SeasonalDisclosureCycleService(
            store: store,
            validator: defaultSeasonalDisclosureCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
