import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending accession metrics through their life cycle and keeps a journal of what it did.
    final class PendingAccessionMetricService {
        var store: any PendingAccessionMetricStore
        var validator: PendingAccessionMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingAccessionMetricStore, validator: PendingAccessionMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending accession metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingAccessionMetricStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending accession metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingAccessionMetricStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newPendingAccessionMetricService(_ store: any PendingAccessionMetricStore, clock: any Kit.Clocks.Clock) -> PendingAccessionMetricService {
        return PendingAccessionMetricService(
            store: store,
            validator: defaultPendingAccessionMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
