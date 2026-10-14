import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach estimates through their life cycle and keeps a journal of what it did.
    final class OutreachEstimateManager {
        var store: any OutreachEstimateStore
        var validator: OutreachEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OutreachEstimateStore, validator: OutreachEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("outreach estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachEstimateStatus.expired)
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

    static func newOutreachEstimateManager(_ store: any OutreachEstimateStore, clock: any Kit.Clocks.Clock) -> OutreachEstimateManager {
        return OutreachEstimateManager(
            store: store,
            validator: defaultOutreachEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
