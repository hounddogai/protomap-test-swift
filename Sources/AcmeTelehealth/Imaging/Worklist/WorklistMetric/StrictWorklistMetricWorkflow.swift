import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict worklist metrics through their life cycle and keeps a journal of what it did.
    final class StrictWorklistMetricService {
        var store: any StrictWorklistMetricStore
        var validator: StrictWorklistMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictWorklistMetricStore, validator: StrictWorklistMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict worklist metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictWorklistMetricStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictWorklistMetricStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newStrictWorklistMetricService(_ store: any StrictWorklistMetricStore, clock: any Kit.Clocks.Clock) -> StrictWorklistMetricService {
        return StrictWorklistMetricService(
            store: store,
            validator: defaultStrictWorklistMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
