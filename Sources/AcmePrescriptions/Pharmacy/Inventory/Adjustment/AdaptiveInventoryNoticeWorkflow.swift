import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves adaptive inventory notices through their life cycle and keeps a journal of what it did.
    final class AdaptiveInventoryNoticeWorkflow {
        var store: any AdaptiveInventoryNoticeStore
        var validator: AdaptiveInventoryNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveInventoryNoticeStore, validator: AdaptiveInventoryNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive inventory notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveInventoryNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive inventory notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveInventoryNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newAdaptiveInventoryNoticeWorkflow(_ store: any AdaptiveInventoryNoticeStore, clock: any Kit.Clocks.Clock) -> AdaptiveInventoryNoticeWorkflow {
        return AdaptiveInventoryNoticeWorkflow(
            store: store,
            validator: defaultAdaptiveInventoryNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
