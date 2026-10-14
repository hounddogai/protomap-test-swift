import AcmePlatform
import Foundation

extension Imaging {
    /// Moves manual worklist digests through their life cycle and keeps a journal of what it did.
    final class ManualWorklistDigestWorkflow {
        var store: any ManualWorklistDigestStore
        var validator: ManualWorklistDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualWorklistDigestStore, validator: ManualWorklistDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual worklist digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualWorklistDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual worklist digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualWorklistDigestStatus.cancelled)
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

    static func newManualWorklistDigestWorkflow(_ store: any ManualWorklistDigestStore, clock: any Kit.Clocks.Clock) -> ManualWorklistDigestWorkflow {
        return ManualWorklistDigestWorkflow(
            store: store,
            validator: defaultManualWorklistDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
